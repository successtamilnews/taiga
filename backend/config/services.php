<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'resend' => [
        'key' => env('RESEND_KEY'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // Payment Gateway Services
    'google_pay' => [
        'environment' => env('GOOGLE_PAY_ENVIRONMENT', 'TEST'),
        'merchant_id' => env('GOOGLE_PAY_MERCHANT_ID'),
        'api_key' => env('GOOGLE_PAY_API_KEY'),
        'webhook_secret' => env('GOOGLE_PAY_WEBHOOK_SECRET'),
    ],

    'apple_pay' => [
        'environment' => env('APPLE_PAY_ENVIRONMENT', 'sandbox'),
        'merchant_id' => env('APPLE_PAY_MERCHANT_ID'),
        'certificate_path' => env('APPLE_PAY_CERTIFICATE_PATH'),
        'certificate_key' => env('APPLE_PAY_CERTIFICATE_KEY'),
    ],

    'sampath_bank' => [
        'environment' => env('SAMPATH_BANK_ENVIRONMENT', 'sandbox'),
        'merchant_id' => env('SAMPATH_BANK_MERCHANT_ID'),
        'api_key' => env('SAMPATH_BANK_API_KEY'),
        'secret_key' => env('SAMPATH_BANK_SECRET_KEY'),
        'base_url' => env('SAMPATH_BANK_BASE_URL', 'https://sandbox.sampathbank.com/ipg'),
    ],

];
