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
        Schema::create('vendors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('business_name');
            $table->string('business_email')->unique();
            $table->string('business_phone');
            $table->text('business_description')->nullable();
            $table->string('business_address');
            $table->string('city');
            $table->string('state');
            $table->string('postal_code');
            $table->string('country');
            $table->string('website')->nullable();
            $table->string('logo')->nullable();
            $table->string('banner')->nullable();
            $table->decimal('commission_rate', 5, 2)->default(10.00);
            $table->enum('status', ['pending', 'approved', 'suspended', 'rejected'])->default('pending');
            $table->json('business_documents')->nullable();
            $table->string('tax_id')->nullable();
            $table->string('bank_account_number')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('account_holder_name')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            
            $table->index(['status']);
            $table->index(['city', 'state']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vendors');
    }
};
