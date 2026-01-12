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
        Schema::create('delivery_persons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('phone');
            $table->string('vehicle_type');
            $table->string('vehicle_number');
            $table->string('license_number');
            $table->json('documents')->nullable();
            $table->enum('status', ['active', 'inactive', 'suspended'])->default('active');
            $table->boolean('is_available')->default(true);
            $table->decimal('current_latitude', 10, 8)->nullable();
            $table->decimal('current_longitude', 11, 8)->nullable();
            $table->timestamp('last_location_update')->nullable();
            $table->json('working_areas')->nullable();
            $table->decimal('rating', 3, 2)->default(0);
            $table->integer('total_deliveries')->default(0);
            $table->timestamps();
            
            $table->index(['status', 'is_available']);
            $table->index(['current_latitude', 'current_longitude']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_persons');
    }
};
