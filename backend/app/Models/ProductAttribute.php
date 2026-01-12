<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
// use Illuminate\Database\Eloquent\SoftDeletes;

class ProductAttribute extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'name',
        'value',
        'type'
    ];

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}