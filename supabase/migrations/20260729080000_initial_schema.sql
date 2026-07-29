-- ============================================================
-- Werk Platform: Initial Database Schema
-- Migration: 20260729080000_initial_schema.sql
-- Description: Creates the foundational tables for profiles,
--              tasks, executions, and execution logs.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- 1. PROFILES
-- Extends Supabase auth.users with application-specific fields
-- ──────────────────────────────────────────────────────────────
CREATE TABLE public.profiles (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT,
    avatar_url  TEXT,
    role        TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'operator', 'user')),
    company     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'User profiles extending Supabase Auth with app-specific metadata.';

-- Automatically create a profile row when a new auth user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
        COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ──────────────────────────────────────────────────────────────
-- 2. TASKS
-- Core work items dispatched to agents by the orchestrator
-- ──────────────────────────────────────────────────────────────
CREATE TABLE public.tasks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT,
    agent_type      TEXT NOT NULL CHECK (agent_type IN ('orchestration', 'analysis', 'coding', 'automation')),
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'queued', 'processing', 'completed', 'failed', 'cancelled')),
    priority        INT NOT NULL DEFAULT 0 CHECK (priority BETWEEN 0 AND 10),
    input_payload   JSONB DEFAULT '{}'::jsonb,
    output_payload  JSONB DEFAULT '{}'::jsonb,
    parent_task_id  UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.tasks IS 'Work items created by users or agents, dispatched to specialized agent types.';

CREATE INDEX idx_tasks_user_id    ON public.tasks(user_id);
CREATE INDEX idx_tasks_status     ON public.tasks(status);
CREATE INDEX idx_tasks_agent_type ON public.tasks(agent_type);
CREATE INDEX idx_tasks_parent     ON public.tasks(parent_task_id);

-- ──────────────────────────────────────────────────────────────
-- 3. EXECUTIONS
-- Individual execution runs of a task by an agent
-- ──────────────────────────────────────────────────────────────
CREATE TABLE public.executions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id         UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    agent_type      TEXT NOT NULL CHECK (agent_type IN ('orchestration', 'analysis', 'coding', 'automation')),
    status          TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'retrying')),
    attempt         INT NOT NULL DEFAULT 1,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at     TIMESTAMPTZ,
    duration_ms     INT,
    error_message   TEXT,
    result_payload  JSONB DEFAULT '{}'::jsonb
);

COMMENT ON TABLE public.executions IS 'Tracks each execution attempt of a task by a specific agent.';

CREATE INDEX idx_executions_task_id    ON public.executions(task_id);
CREATE INDEX idx_executions_status     ON public.executions(status);
CREATE INDEX idx_executions_agent_type ON public.executions(agent_type);

-- ──────────────────────────────────────────────────────────────
-- 4. EXECUTION LOGS
-- Granular, append-only log entries for auditing agent activity
-- ──────────────────────────────────────────────────────────────
CREATE TABLE public.execution_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_id    UUID NOT NULL REFERENCES public.executions(id) ON DELETE CASCADE,
    level           TEXT NOT NULL DEFAULT 'info' CHECK (level IN ('debug', 'info', 'warn', 'error')),
    message         TEXT NOT NULL,
    metadata        JSONB DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.execution_logs IS 'Append-only audit log of agent actions during an execution run.';

CREATE INDEX idx_execution_logs_execution_id ON public.execution_logs(execution_id);
CREATE INDEX idx_execution_logs_level        ON public.execution_logs(level);
CREATE INDEX idx_execution_logs_created_at   ON public.execution_logs(created_at);

-- ──────────────────────────────────────────────────────────────
-- 5. UPDATED_AT TRIGGER
-- Automatically refreshes updated_at on row modification
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ──────────────────────────────────────────────────────────────
-- 6. ROW LEVEL SECURITY (RLS)
-- Ensures users can only access their own data
-- ──────────────────────────────────────────────────────────────

-- Profiles: users can read/update their own profile; admins can read all
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
    ON public.profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
    );

-- Tasks: users see their own tasks; admins and operators see all
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own tasks"
    ON public.tasks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own tasks"
    ON public.tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins and operators can view all tasks"
    ON public.tasks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'operator')
        )
    );

-- Executions: visible to task owner and admins/operators
ALTER TABLE public.executions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view executions of their tasks"
    ON public.executions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = executions.task_id AND t.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins and operators can view all executions"
    ON public.executions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'operator')
        )
    );

-- Execution logs: visible to task owner and admins/operators
ALTER TABLE public.execution_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view logs of their executions"
    ON public.execution_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.executions e
            JOIN public.tasks t ON t.id = e.task_id
            WHERE e.id = execution_logs.execution_id AND t.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins and operators can view all logs"
    ON public.execution_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'operator')
        )
    );

-- ──────────────────────────────────────────────────────────────
-- 7. ENABLE REALTIME
-- Publish changes for live UI subscriptions
-- ──────────────────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.executions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.execution_logs;
