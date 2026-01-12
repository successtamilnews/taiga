<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Builder;

class DeliveryPerson extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'phone',
        'vehicle_type',
        'vehicle_number',
        'license_number',
        'documents',
        'status',
        'is_available',
        'current_latitude',
        'current_longitude',
        'last_location_update',
        'working_areas',
        'rating',
        'total_deliveries',
    ];

    protected $casts = [
        'documents' => 'array',
        'is_available' => 'boolean',
        'current_latitude' => 'decimal:8',
        'current_longitude' => 'decimal:8',
        'last_location_update' => 'datetime',
        'working_areas' => 'array',
        'rating' => 'decimal:2',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', 'active');
    }

    public function scopeAvailable(Builder $query): Builder
    {
        return $query->where('is_available', true)
                    ->where('status', 'active');
    }

    public function updateLocation(float $latitude, float $longitude): void
    {
        $this->update([
            'current_latitude' => $latitude,
            'current_longitude' => $longitude,
            'last_location_update' => now(),
        ]);
    }

    public function markAvailable(): void
    {
        $this->update(['is_available' => true]);
    }

    public function markBusy(): void
    {
        $this->update(['is_available' => false]);
    }
}
