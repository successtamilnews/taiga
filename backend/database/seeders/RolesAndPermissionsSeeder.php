<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // Create permissions
        $permissions = [
            // Product permissions
            'view products',
            'create products',
            'edit products',
            'delete products',
            'approve products',
            
            // Order permissions
            'view orders',
            'create orders',
            'edit orders',
            'cancel orders',
            'fulfill orders',
            
            // User permissions
            'view users',
            'create users',
            'edit users',
            'delete users',
            'ban users',
            
            // Vendor permissions
            'view vendors',
            'approve vendors',
            'suspend vendors',
            'edit vendor commission',
            
            // Admin permissions
            'view admin dashboard',
            'manage settings',
            'view analytics',
            'generate reports',
            
            // Delivery permissions
            'view deliveries',
            'accept deliveries',
            'update delivery status',
            'track location',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Create roles and assign permissions
        $customerRole = Role::firstOrCreate(['name' => 'customer']);
        $customerRole->givePermissionTo([
            'view products',
            'create orders',
            'view orders',
            'cancel orders',
        ]);

        $vendorRole = Role::firstOrCreate(['name' => 'vendor']);
        $vendorRole->givePermissionTo([
            'view products',
            'create products',
            'edit products',
            'view orders',
            'fulfill orders',
            'view analytics',
        ]);

        $deliveryRole = Role::firstOrCreate(['name' => 'delivery']);
        $deliveryRole->givePermissionTo([
            'view deliveries',
            'accept deliveries',
            'update delivery status',
            'track location',
        ]);

        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $adminRole->givePermissionTo(Permission::all());

        // Create admin user
        $admin = User::create([
            'name' => 'Admin User',
            'email' => 'admin@taiga.com',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
        ]);
        $admin->assignRole('admin');

        // Create sample vendor user
        $vendor = User::create([
            'name' => 'Sample Vendor',
            'email' => 'vendor@taiga.com',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
        ]);
        $vendor->assignRole('vendor');

        // Create sample customer
        $customer = User::create([
            'name' => 'Sample Customer',
            'email' => 'customer@taiga.com',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
        ]);
        $customer->assignRole('customer');

        // Create sample delivery person
        $delivery = User::create([
            'name' => 'Delivery Person',
            'email' => 'delivery@taiga.com',
            'password' => Hash::make('password'),
            'email_verified_at' => now(),
        ]);
        $delivery->assignRole('delivery');

        $this->command->info('Roles and permissions created successfully!');
        $this->command->info('Admin credentials: admin@taiga.com / password');
        $this->command->info('Vendor credentials: vendor@taiga.com / password');
        $this->command->info('Customer credentials: customer@taiga.com / password');
        $this->command->info('Delivery credentials: delivery@taiga.com / password');
    }
}
