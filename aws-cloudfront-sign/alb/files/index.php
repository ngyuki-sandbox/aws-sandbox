<?php
$rsaKeyPairIdPath = '/opt/app/secret/rsa_key_pair_id';
$rsaPrivateKeyPath = '/opt/app/secret/rsa_private_key';

$ecdsaKeyPairIdPath = '/opt/app/secret/ecdsa_key_pair_id';
$ecdsaPrivateKeyPath = '/opt/app/secret/ecdsa_private_key';

function issueSignedCookies($keyPairIdPath, $privateKeyPath) {
    $expires = time() + 3600;
    $host = $_SERVER['HTTP_HOST'];
    $policy = json_encode([
        'Statement' => [[
            'Resource' => "https://$host/*",
            'Condition' => [
                'DateLessThan' => ['AWS:EpochTime' => $expires],
            ],
        ]],
    ], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

    $keyPairId = file_get_contents($keyPairIdPath);
    $privateKey = file_get_contents($privateKeyPath);
    $signature = '';
    if (!openssl_sign($policy, $signature, $privateKey, OPENSSL_ALGO_SHA1)) {
        return;
    }

    $cookieOptions = [
        'path' => '/',
        'secure' => true,
        'httponly' => true,
        'samesite' => 'Strict',
    ];

    setcookie('CloudFront-Policy', urlSafeBase64Encode($policy), $cookieOptions);
    setcookie('CloudFront-Signature', urlSafeBase64Encode($signature), $cookieOptions);
    setcookie('CloudFront-Key-Pair-Id', $keyPairId, $cookieOptions);
}

function clearSignedCookies() {
    $cookieOptions = [
        'expires' => time() - 3600,
        'path' => '/',
    ];
    setcookie('CloudFront-Policy', '', $cookieOptions);
    setcookie('CloudFront-Signature', '', $cookieOptions);
    setcookie('CloudFront-Key-Pair-Id', '', $cookieOptions);
}

function urlSafeBase64Encode($value) {
    $encoded = base64_encode($value);
    return str_replace(
        ['+', '=', '/'],
        ['-', '_', '~'],
        $encoded);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'];
    switch ($action) {
        case 'rsa': {
            issueSignedCookies($rsaKeyPairIdPath, $rsaPrivateKeyPath);
            break;
        }
        case 'ecdsa': {
            issueSignedCookies($ecdsaKeyPairIdPath, $ecdsaPrivateKeyPath);
            break;
        }
        case 'clear': {
            clearSignedCookies();
            break;
        }
    }
    header("Location: /");
    exit;
}
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title></title>
    <link rel="stylesheet" href="/static/style.css">
    <script src="/static/script.js"></script>
</head>
<body>
    <form method="POST">
        <button type="submit" name="action" value="rsa">rsa</button>
        <button type="submit" name="action" value="ecdsa">ecdsa</button>
        <button type="submit" name="action" value="clear">clear</button>
    </form>
    <img src="/private/image.png">
</body>
</html>
