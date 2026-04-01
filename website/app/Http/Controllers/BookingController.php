<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function index(Request $request)
    {
        // sport param bisa dipakai untuk pre-select di JS via URL
        return view('booking');
    }
}
