# AWS DMS でデータのマスキング

本番環境からデータをマスキングして検証用のデータベースを作成する例。

- replication_task_settings.FullLoadSettings.TargetTablePrepMode を TRUNCATE_BEFORE_LOAD とすることで既存のテーブル定義をそのまま残す
- add-column でマスクしたい列に適当な expression で値を適用する
    - add-column と言っても実際に列が追加されるわけではない
- add-column の expression で同列を参照するとエラー

最初に検証用のデータベースをスナップショットからリストアしているものの、
実際にはテーブル定義だけあればよいので空で作成の上でスキーマだけダンプ・リストアで OK です。
むしろマスキング前のデータが検証用データベースに一時的にせよ存在するのは好ましくないので、
スナップショットからのリストアはやらないほうが良い。
