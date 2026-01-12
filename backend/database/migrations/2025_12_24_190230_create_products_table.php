<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vendor_id')->constrained()->onDelete('cascade');
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description');
            $table->text('short_description')->nullable();
            $table->string('sku')->unique();
            $table->decimal('price', 10, 2);
            $table->decimal('sale_price', 10, 2)->nullable();
            $table->integer('stock_quantity')->default(0);
            $table->boolean('manage_stock')->default(true);
            $table->enum('stock_status', ['in_stock', 'out_of_stock', 'on_backorder'])->default('in_stock');
            $table->decimal('weight', 8, 2)->nullable();
            $table->json('dimensions')->nullable();
            $table->json('images')->nullable();
            $table->json('gallery')->nullable();
            $table->enum('type', ['physical', 'digital'])->default('physical');
            $table->enum('status', ['draft', 'pending', 'approved', 'rejected'])->default('draft');
            $table->boolean('is_featured')->default(false);
            $table->json('attributes')->nullable();
            $table->json('variations')->nullable();
            $table->string('digital_file')->nullable();
            $table->integer('download_limit')->nullable();
            $table->integer('download_expiry')->nullable();
            $table->json('seo_meta')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            
            $table->index(['vendor_id', 'status']);
            $table->index(['category_id', 'status']);
            $table->index(['status', 'is_featured']);
            $table->index(['type', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
