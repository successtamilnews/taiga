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
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->string('action');
            $table->string('resource');
            $table->unsignedBigInteger('resource_id');
            $table->json('context')->nullable();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->ipAddress('ip_address')->nullable();
            $table->timestamps();
            
            $table->index(['resource', 'resource_id']);
            $table->index(['user_id', 'created_at']);
            $table->index(['action', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};