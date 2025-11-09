-- =============================
-- DDL: Tabela final desnormalizada (Aurora PostgreSQL)
-- =============================

-- Mantemos apenas a tabela desnormalizada de performance acadêmica.
-- A chave primária é composta para permitir múltiplas linhas por aluno (por escola/disciplina).
CREATE TABLE IF NOT EXISTS public.performance_academica (
    aluno_id BIGINT,
    nome_aluno VARCHAR(255),
    idade INT,
    genero VARCHAR(50),
    escola_id BIGINT,
    nome_escola VARCHAR(255),
    rede VARCHAR(50),
    regiao VARCHAR(100),
    disciplina VARCHAR(100),
    nota DECIMAL(4,2),
    PRIMARY KEY (aluno_id, escola_id, disciplina)
);

CREATE INDEX IF NOT EXISTS idx_performance_escola ON public.performance_academica(escola_id);
CREATE INDEX IF NOT EXISTS idx_performance_rede ON public.performance_academica(rede);
CREATE INDEX IF NOT EXISTS idx_performance_regiao ON public.performance_academica(regiao);
CREATE INDEX IF NOT EXISTS idx_performance_disciplina ON public.performance_academica(disciplina);