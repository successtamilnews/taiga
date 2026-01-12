<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Vendor;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;

class UsersSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create Admin User
        $admin = User::firstOrCreate(
            ['email' => 'admin@taiga.com'],
            [
                'name' => 'Admin User',
                'email' => 'admin@taiga.com',
                'password' => Hash::make('password'),
                'email_verified_at' => now(),
                'role' => 'admin'
            ]
        );

        // Assign admin role
        if (Role::where('name', 'admin')->exists()) {
            $admin->assignRole('admin');
        }

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

        // Assign vendor role
        if (Role::where('name', 'vendor')->exists()) {
            $vendor->assignRole('vendor');
        }

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

        // Assign customer role
        if (Role::where('name', 'customer')->exists()) {
            $customer->assignRole('customer');
        }

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

        // Assign delivery role
        if (Role::where('name', 'delivery')->exists()) {
            $delivery->assignRole('delivery');
        }

        $this->command->info('Demo users created successfully!');
        $this->command->info('Admin: admin@taiga.com / password');
        $this->command->info('Vendor: vendor@taiga.com / password');
        $this->command->info('Customer: customer@taiga.com / password');
        $this->command->info('Delivery: delivery@taiga.com / password');
    }
}