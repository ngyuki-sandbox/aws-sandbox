<?php
require __DIR__ . '/../vendor/autoload.php';

new class () {
    private string $baseUrl;

    public function __construct()
    {
        $runtimeApi = getenv('AWS_LAMBDA_RUNTIME_API');
        if (strlen($runtimeApi) == 0) {
            throw new LogicException('Missing Runtime API Server configuration.');
        }

        $this->baseUrl = "http://$runtimeApi/2018-06-01";

        $argv = $_SERVER['argv'];
        if (count($argv) < 2) {
            throw new LogicException('No handler specified.');
        }

        $appRoot = getcwd();
        $handlerName = $argv[1];
        $function = require "$appRoot/$handlerName";

        do {
            list ($invocationId, $payload) = $this->getNextRequest();
            try {
                $response = $function($payload);
                $this->sendResponse($invocationId, $response);
            } catch (Throwable $ex) {
                $this->handleFailure($invocationId, $ex);
            }
        } while (true);
    }

    private function getNextRequest(): array
    {
        $url = "$this->baseUrl/runtime/invocation/next";
        $client = new GuzzleHttp\Client();
        $response = $client->get($url);
        $invocationId = $response->getHeaderLine('lambda-runtime-aws-request-id');
        $payload = json_decode($response->getBody(), true);
        return [$invocationId, $payload];
    }

    private function sendResponse(string $invocationId, $response): void
    {
        $url = "$this->baseUrl/runtime/invocation/$invocationId/response";
        $payload = json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $client = new GuzzleHttp\Client();
        $client->post($url, [
            'headers' => [
                'Content-Type' => 'application/json',
            ],
            'body' => $payload,
        ]);
    }

    private function handleFailure(string $invocationId, Throwable $exception): void
    {
        $url = "$this->baseUrl/runtime/invocation/$invocationId/error";
        $data = [
            'errorType' => get_class($exception),
            'errorMessage' => $exception->getMessage(),
        ];
        $payload = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        $client = new GuzzleHttp\Client();
        $client->post($url, [
            'headers' => [
                'Content-Type' => 'application/json',
            ],
            'body' => $payload,
        ]);
    }
};

