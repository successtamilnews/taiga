<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vendor extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'business_name',
        'business_email',
        'business_phone',
        'business_description',
        'business_address',
        'city',
        'state',
        'postal_code',
        'country',
        'website',
        'logo',
        'banner',
        'commission_rate',
        'status',
        'business_documents',
        'tax_id',
        'bank_account_number',
        'bank_name',
        'account_holder_name',
        'approved_at',
    ];

    protected $casts = [
        'business_documents' => 'array',
        'commission_rate' => 'decimal:2',
        'approved_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function calculateCommission(float $amount): float
    {
        return ($amount * $this->commission_rate) / 100;
    }
}
