<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Builder;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'vendor_id',
        'category_id',
        'name',
        'slug',
        'description',
        'short_description',
        'sku',
        'price',
        'sale_price',
        'stock_quantity',
        'manage_stock',
        'stock_status',
        'weight',
        'dimensions',
        'images',
        'gallery',
        'type',
        'status',
        'is_featured',
        'attributes',
        'variations',
        'digital_file',
        'download_limit',
        'download_expiry',
        'seo_meta',
        'approved_at',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'sale_price' => 'decimal:2',
        'weight' => 'decimal:2',
        'dimensions' => 'array',
        'images' => 'array',
        'gallery' => 'array',
        'attributes' => 'array',
        'variations' => 'array',
        'seo_meta' => 'array',
        'is_featured' => 'boolean',
        'manage_stock' => 'boolean',
        'approved_at' => 'datetime',
    ];

    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class);
    }

    public function attributes(): HasMany
    {
        return $this->hasMany(ProductAttribute::class);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(ProductReview::class);
    }

    public function wishlistItems(): HasMany
    {
        return $this->hasMany(WishlistItem::class);
    }

    public function scopeApproved(Builder $query): Builder
    {
        return $query->where('status', 'approved');
    }

    public function scopeInStock(Builder $query): Builder
    {
        return $query->where('stock_status', 'in_stock');
    }

    public function scopeFeatured(Builder $query): Builder
    {
        return $query->where('is_featured', true);
    }

    public function getEffectivePrice(): float
    {
        return $this->sale_price ?? $this->price;
    }

    public function isInStock(): bool
    {
        return $this->stock_status === 'in_stock' && ($this->stock_quantity > 0 || !$this->manage_stock);
    }

    public function isDigital(): bool
    {
        return $this->type === 'digital';
    }
}
