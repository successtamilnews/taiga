<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;
use Illuminate\Support\Str;

class CategoriesSeeder extends Seeder
{
    public function run(): void
    {
        $names = [
            'Electronics & Mobile Gadgets',
            'Mobile Accessories & Chargers',
            'Home, Kitchen & Living Essentials',
            'Beauty, Health & Personal Care',
            'Fashion & Accessories',
            'Fitness, Sports & Outdoor',
            'Toys, Hobbies, DIY & Kids',
            'Travel, Automobile & Gaming',
            'Pet & Eco-Friendly Products',
            'Premium, Gift, Trending & Seasonal Items',
        ];

        $slugs = [];
        foreach ($names as $index => $name) {
            $slug = Str::slug($name);
            $slugs[] = $slug;

            Category::updateOrCreate(
                ['slug' => $slug],
                [
                    'name' => $name,
                    'description' => $name,
                    'is_active' => true,
                    'sort_order' => $index,
                    'parent_id' => null,
                ]
            );
        }

        // Deactivate any categories not in the new set (keeps data without destructive delete)
        Category::whereNotIn('slug', $slugs)->update(['is_active' => false]);

        $this->command->info('Categories created successfully!');
    }
}
