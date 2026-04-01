<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HomeController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PaymentController;

/*
|--------------------------------------------------------------------------
| SIPELOR BEDAS — Web Routes
|--------------------------------------------------------------------------
*/

// Landing page
Route::get('/', [HomeController::class, 'index'])->name('home');

// Booking
Route::get('/booking', [BookingController::class, 'index'])->name('booking');

// Auth (login/register — handled via Supabase JS)
Route::get('/login', [AuthController::class, 'index'])->name('login');

// Payment
Route::get('/payment', [PaymentController::class, 'index'])->name('payment');
