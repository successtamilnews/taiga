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
        Schema::create('payment_audit_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('payment_id');
            $table->string('event');
            $table->decimal('amount', 10, 2);
            $table->json('context');
            $table->unsignedBigInteger('user_id')->nullable();
            $table->timestamp('created_at');
            
            $table->foreign('payment_id')->references('id')->on('payments')->onDelete('cascade');
            $table->index(['payment_id', 'created_at']);
            $table->index(['event', 'created_at']);
            $table->index(['amount', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_audit_logs');
    }
};