# NUSA-DHIPA Verification Model

## Core principle

Legalitas bukan syarat untuk masuk Marketplace.

Bisnis tanpa legalitas tetap dapat:

- membuat Business Profile
- menggunakan Business OS
- menggunakan Mobile App
- masuk Marketplace
- mulai berjualan

## Verification

Verification adalah trust layer.

Status:

- unverified
- in_process
- verified
- suspended
- expired

## Important

UNVERIFIED != ILLEGAL

Gunakan:

Belum Terverifikasi

Bukan:

Bisnis Tidak Legal

## Verified Badge

Badge hanya muncul apabila:

status = verified
verified = true

Badge:

NUSA-DHIPA VERIFIED

QR hanya tersedia untuk bisnis yang sudah verified.

## Public QR

QR mengarah ke:

/verify/{verification_code}

Contoh:

/verify/NDH-A1B2C3D4

QR tidak boleh membawa:

- NIB
- AHU
- NPWP
- identitas pemilik
- alamat pribadi
- dokumen legal

## Database

business_verifications

verification_audits

public_business_verifications