-- https://sqlite.readdevdocs.com/fts5.html#tokenizers
CREATE VIRTUAL TABLE t1 USING fts5(x, tokenize = 'trigram', detail=column);
insert into t1 values
('转换sql查询为物化视图'),
('Analyze the following JSON data to convert it into a {} {}.\nDo not explain.\n```\n{}\n```'),
('### Role\nYou are a git diff summary assistant.\n\n### Goals\nExtract commit messages from the `git diff` output\n\n## Constraints\nsummarize only the content changes within files, ignore changes in hashes, and generate a title based on these summaries.\n\n### Attention\n- Lines starting with `+` indicate new lines added.\n- Lines starting with `-` indicate deleted lines.\n- Other lines are context and are not part of the current change being described.'),
('解释以下单词含义，用法，并列出同义词，近义词和反义词:\n```{}```'),
('trans select into material view query SQL')
returning rowid;
select rowid, * from t1;
select rowid, * from t1 where x match 'sql';
select rowid, * from t1 where x rowid = 1;
