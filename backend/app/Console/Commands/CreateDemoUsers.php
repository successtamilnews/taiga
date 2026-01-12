<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Vendor;
use Illuminate\Support\Facades\Hash;

class CreateDemoUsers extends Command
{
    protected $signature = 'demo:create-users';
    protected $description = 'Create demo users for testing';

    public function handle()
    {
        $this->info('Creating demo users...');

        // Create Vendor User
        $vendor = User::firstOrCreate(
            ['email' => 'vendor@taiga.com'],
            [
                'name' => 'Demo Vendor',
                'email' => 'vendor@taiga.com',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
                'role' => 'vendor'
            ]
        );
        $this->info('✅ Vendor user: ' . $vendor->name);

        // Create Vendor Profile
        if ($vendor && !$vendor->vendor) {
            Vendor::firstOrCreate(
                ['user_id' => $vendor->id],
                [
                    'user_id' => $vendor->id,
                    'business_name' => 'Demo Store',
                    'business_email' => 'vendor@taiga.com',
                    'business_phone' => '+1234567890',
                    'business_description' => 'Demo vendor store for testing',
                    'business_address' => '123 Demo Street',
                    'city' => 'Demo City',
                    'state' => 'Demo State',
                    'postal_code' => '12345',
                    'country' => 'Demo Country',
                    'status' => 'approved',
                    'commission_rate' => 10.00,
                ]
            );
            $this->info('✅ Vendor profile created');
        }

        // Create Customer User
        $customer = User::firstOrCreate(
            ['email' => 'customer@taiga.com'],
            [
                'name' => 'Demo Customer',
                'email' => 'customer@taiga.com',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
                'role' => 'customer'
            ]
        );
        $this->info('✅ Customer user: ' . $customer->name);

        // Create Delivery Person
        $delivery = User::firstOrCreate(
            ['email' => 'delivery@taiga.com'],
            [
                'name' => 'Demo Delivery Person',
                'email' => 'delivery@taiga.com',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
                'role' => 'delivery'
            ]
        );
        $this->info('✅ Delivery user: ' . $delivery->name);

        $this->info('All demo users created successfully!');
        return 0;
    }
}