<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function index(Request $request)
    {
        // booking_code, field, date, time, duration, total di-pass via URL query params
        // dibaca oleh payment.js di sisi klien
        return view('payment');
    }
}
