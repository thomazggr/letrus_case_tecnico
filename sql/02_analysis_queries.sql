SELECT
    regiao,
    nome_escola,
    AVG(nota) AS media_notas
FROM
    public.performance_academica
GROUP BY
    regiao,
    nome_escola
ORDER BY
    regiao,
    media_notas DESC;

SELECT
    rede,
    AVG(nota) AS media_geral,
    COUNT(DISTINCT escola_id) AS total_escolas,
    COUNT(DISTINCT aluno_id) AS total_alunos
FROM
    public.performance_academica
GROUP BY
    rede;

SELECT
    disciplina,
    AVG(nota) AS media_disciplina,
    MIN(nota) AS nota_minima,
    MAX(nota) AS nota_maxima,
    COUNT(*) AS total_avaliacoes
FROM
    public.performance_academica
GROUP BY
    disciplina
ORDER BY
    media_disciplina DESC;