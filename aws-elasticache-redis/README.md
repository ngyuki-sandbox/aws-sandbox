# ElastiCache for Redis

- クラスターモードの有効/無効は parameter_group_name でも決まる
    - num_node_groups が 1 や省略でもパラメータグループによりクラスターモード有効にできる
- replicas_per_node_group を指定しても num_node_groups が未指定ならクラスターモード無効になる
    - replicas_per_node_group と num_cache_clusters が別々の設定にある意味が良くわからない
