<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImage;
use App\Models\ProductAttribute;
use App\Models\Vendor;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class EcommerceSeeder extends Seeder
{
    public function run(): void
    {
        // Create roles
        $adminRole = Role::firstOrCreate(['name' => 'admin']);
        $vendorRole = Role::firstOrCreate(['name' => 'vendor']);
        $customerRole = Role::firstOrCreate(['name' => 'customer']);
        $deliveryRole = Role::firstOrCreate(['name' => 'delivery']);

        // Create permissions
        $permissions = [
            'manage-users',
            'manage-products',
            'manage-orders',
            'manage-vendors',
            'view-analytics',
            'manage-categories',
            'manage-payments',
            'view-own-products',
            'view-own-orders',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission]);
        }

        // Assign permissions to roles
        $adminRole->syncPermissions($permissions);
        $vendorRole->syncPermissions(['view-own-products', 'view-own-orders', 'manage-products']);

        // Create admin user
        $admin = User::firstOrCreate(
            ['email' => 'admin@taiga.com'],
            [
                'name' => 'Admin User',
                'password' => Hash::make('password'),
                'type' => 'admin',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        $admin->assignRole($adminRole);

        // Create vendor user
        $vendorUser = User::firstOrCreate(
            ['email' => 'vendor@taiga.com'],
            [
                'name' => 'Vendor User',
                'password' => Hash::make('password'),
                'type' => 'vendor',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        $vendorUser->assignRole($vendorRole);

        // Create vendor profile
        $vendor = Vendor::firstOrCreate(
            ['user_id' => $vendorUser->id],
            [
                'business_name' => 'Demo Store',
                'business_email' => 'vendor@taiga.com',
                'business_phone' => '+94771234567',
                'business_description' => 'Demo vendor store for testing',
                'business_address' => '123 Demo Street',
                'city' => 'Demo City',
                'state' => 'Demo State',
                'postal_code' => '12345',
                'country' => 'Sri Lanka',
                'status' => 'approved',
                'commission_rate' => 10.00,
                'approved_at' => now(),
            ]
        );

        // Create customer user
        $customer = User::firstOrCreate(
            ['email' => 'customer@taiga.com'],
            [
                'name' => 'Customer User',
                'password' => Hash::make('password'),
                'type' => 'customer',
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );
        $customer->assignRole($customerRole);

        // Create categories
        $categories = [
            ['name' => 'Electronics', 'slug' => 'electronics', 'description' => 'Electronic devices and gadgets'],
            ['name' => 'Fashion', 'slug' => 'fashion', 'description' => 'Clothing and accessories'],
            ['name' => 'Home & Garden', 'slug' => 'home-garden', 'description' => 'Home and garden items'],
            ['name' => 'Sports', 'slug' => 'sports', 'description' => 'Sports and fitness equipment'],
            ['name' => 'Books', 'slug' => 'books', 'description' => 'Books and literature'],
        ];

        foreach ($categories as $categoryData) {
            $category = Category::firstOrCreate(
                ['slug' => $categoryData['slug']],
                [
                    'name' => $categoryData['name'],
                    'description' => $categoryData['description'],
                    'is_active' => true,
                    'sort_order' => 1,
                ]
            );

            // Create some products for each category
            $this->createSampleProducts($category, $vendor);
        }
    }

    private function createSampleProducts($category, $vendor)
    {
        $products = [
            [
                'name' => 'Sample Product 1',
                'description' => 'This is a sample product description for product 1.',
                'short_description' => 'Sample product 1 short description',
                'price' => 99.99,
                'sale_price' => 89.99,
                'stock_quantity' => 100,
            ],
            [
                'name' => 'Sample Product 2', 
                'description' => 'This is a sample product description for product 2.',
                'short_description' => 'Sample product 2 short description',
                'price' => 149.99,
                'stock_quantity' => 50,
            ],
        ];

        foreach ($products as $index => $productData) {
            $product = Product::firstOrCreate(
                [
                    'name' => $productData['name'] . ' - ' . $category->name,
                    'category_id' => $category->id,
                ],
                [
                    'vendor_id' => $vendor->id,
                    'slug' => \Str::slug($productData['name'] . ' ' . $category->name),
                    'description' => $productData['description'],
                    'short_description' => $productData['short_description'],
                    'sku' => 'SKU-' . strtoupper(\Str::random(6)),
                    'price' => $productData['price'],
                    'sale_price' => $productData['sale_price'] ?? null,
                    'stock_quantity' => $productData['stock_quantity'],
                    'manage_stock' => true,
                    'stock_status' => 'in_stock',
                    'type' => 'physical',
                    'status' => 'approved',
                    'is_featured' => $index === 0,
                ]
            );

            // Add sample images
            ProductImage::firstOrCreate(
                ['product_id' => $product->id, 'sort_order' => 1],
                [
                    'url' => 'https://via.placeholder.com/400x400?text=' . urlencode($product->name),
                    'alt_text' => $product->name,
                    'is_primary' => true,
                ]
            );

            // Add sample attributes
            ProductAttribute::firstOrCreate(
                ['product_id' => $product->id, 'name' => 'Color'],
                [
                    'value' => ['Red', 'Blue', 'Green'][array_rand(['Red', 'Blue', 'Green'])],
                    'type' => 'color',
                ]
            );

            ProductAttribute::firstOrCreate(
                ['product_id' => $product->id, 'name' => 'Material'],
                [
                    'value' => ['Cotton', 'Polyester', 'Plastic'][array_rand(['Cotton', 'Polyester', 'Plastic'])],
                    'type' => 'text',
                ]
            );
        }
    }
}