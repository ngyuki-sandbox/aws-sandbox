<?php
$date = date("Y-m-d\TH:m:s");

header('Cache-Control: no-store');
header("ETag: \"$date\"");

$data = [
    'date' => date("Y-m-d\TH:m:s"),
    'headers' => getallheaders(),
    'query' => $_GET,
];
echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . PHP_EOL;
