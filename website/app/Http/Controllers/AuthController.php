<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function index(Request $request)
    {
        // tab=register bisa dipakai untuk auto-switch form
        return view('auth.login');
    }
}
