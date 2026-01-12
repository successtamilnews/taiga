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
        Schema::create('order_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('order_id');
            $table->string('event');
            $table->json('context');
            $table->unsignedBigInteger('user_id')->nullable();
            $table->timestamp('created_at');
            
            $table->foreign('order_id')->references('id')->on('orders')->onDelete('cascade');
            $table->index(['order_id', 'created_at']);
            $table->index(['event', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_audit_logs');
    }
};