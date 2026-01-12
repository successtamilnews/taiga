<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Builder;
use Carbon\Carbon;

class Coupon extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'name',
        'description',
        'type',
        'value',
        'minimum_amount',
        'maximum_discount',
        'usage_limit',
        'used_count',
        'usage_limit_per_user',
        'is_active',
        'starts_at',
        'expires_at',
        'applicable_products',
        'applicable_categories',
        'excluded_products',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'minimum_amount' => 'decimal:2',
        'maximum_discount' => 'decimal:2',
        'is_active' => 'boolean',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'applicable_products' => 'array',
        'applicable_categories' => 'array',
        'excluded_products' => 'array',
    ];

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('is_active', true)
                    ->where(function ($q) {
                        $q->whereNull('starts_at')
                          ->orWhere('starts_at', '<=', now());
                    })
                    ->where(function ($q) {
                        $q->whereNull('expires_at')
                          ->orWhere('expires_at', '>=', now());
                    });
    }

    public function isValid(): bool
    {
        if (!$this->is_active) return false;
        if ($this->starts_at && $this->starts_at->isFuture()) return false;
        if ($this->expires_at && $this->expires_at->isPast()) return false;
        if ($this->usage_limit && $this->used_count >= $this->usage_limit) return false;
        
        return true;
    }

    public function calculateDiscount(float $amount): float
    {
        if (!$this->isValid()) return 0;
        if ($this->minimum_amount && $amount < $this->minimum_amount) return 0;

        $discount = $this->type === 'percentage' 
            ? ($amount * $this->value) / 100 
            : $this->value;

        if ($this->maximum_discount && $discount > $this->maximum_discount) {
            $discount = $this->maximum_discount;
        }

        return $discount;
    }
}
