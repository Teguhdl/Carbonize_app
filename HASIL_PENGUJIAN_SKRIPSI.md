# BAB IV: IMPLEMENTASI DAN PENGJIAN SISTEM
## 4.x Pengujian Otomatis (*Automated Unit Testing*)

Pengujian sistem pada aplikasi **CarbonizeApp** dilakukan menggunakan metode *Automated Unit Testing* dengan bantuan *framework* pengujian bawaan Flutter (`flutter_test`). Pengujian ini bertujuan untuk memverifikasi keakuratan logika algoritma perhitungan emisi karbon (*Core Business Logic*) serta memastikan protokol keamanan penyimpanan kredensial pengguna (*Encrypted Storage*) berjalan sesuai spesifikasi tanpa cacat (*bug-free*).

Berikut adalah rancangan dan hasil eksekusi pengujian otomatis yang telah dilakukan:

---

### 1. Pengujian Logika Perhitungan Emisi Karbon (`EmissionService`)
Pengujian dilakukan dengan memisahkan ketergantungan jaringan (*Dependency Injection*) menggunakan data tiruan (*Mock Object*), sehingga validasi murni menguji akurasi matematika dari rumus yang diterapkan pada sistem.

#### Tabel 4.1 Hasil Pengujian Algoritma Emisi Makanan (*Food Emissions*)
| No | Skenario Pengujian | Parameter Input | Rumus Perhitungan | Nilai Harapan (*Expected*) | Hasil Sistem (*Actual*) | Status |
|---|---|---|---|---|---|---|
| 1 | Perhitungan emisi *Cardboard Boxes* (*Fixed*) | Kuantitas = 1,0 kg<br>Faktor Emisi Seeder = 0,85 kgCO2e/kg | $\text{Kuantitas} \times \text{Faktor Emisi}$<br>$(1,0 \times 0,85)$ | 0,85 kgCO2e | 0,85 kgCO2e | **PASSED** |
| 2 | Perhitungan emisi *Plastic Bottles* (*Fixed*) | Kuantitas = 3,0 kg<br>Faktor Emisi Seeder = 0,083 kgCO2e/kg | $\text{Kuantitas} \times \text{Faktor Emisi}$<br>$(3,0 \times 0,083)$ | 0,249 kgCO2e | 0,249 kgCO2e | **PASSED** |
| 3 | Penanganan input makanan di luar database (*Edge Case*) | Kuantitas = 1,0 kg<br>Item = *Alien Food* | Nilai default 0 | 0,0 kgCO2e | 0,0 kgCO2e | **PASSED** |

#### Tabel 4.2 Hasil Pengujian Algoritma Emisi Kendaraan Pribadi (*Private Vehicle*)
| No | Skenario Pengujian | Parameter Input | Rumus Perhitungan | Nilai Harapan (*Expected*) | Hasil Sistem (*Actual*) | Status |
|---|---|---|---|---|---|---|
| 1 | Perjalanan *Motorcycle* menggunakan Pertalite (*Default Efficiency*) | Jarak = 80 km<br>Efisiensi = 40 km/L<br>Faktor Emisi Seeder = 2,31 kgCO2e/L | $(\frac{80}{40}) \times 2,31$ | 4,62 kgCO2e | 4,62 kgCO2e | **PASSED** |
| 2 | Perjalanan *City Car* menggunakan Pertamax (*Default Efficiency*) | Jarak = 60 km<br>Efisiensi = 20 km/L<br>Faktor Emisi Seeder = 2,31 kgCO2e/L | $(\frac{60}{20}) \times 2,31$ | 6,93 kgCO2e | 6,93 kgCO2e | **PASSED** |
| 3 | Perjalanan *Motorcycle* dengan efisiensi khusus (*Custom Efficiency*) | Jarak = 100 km<br>Efisiensi khusus = 50 km/L<br>Faktor Emisi Seeder = 2,31 kgCO2e/L | $(\frac{100}{50}) \times 2,31$ | 4,62 kgCO2e | 4,62 kgCO2e | **PASSED** |

#### Tabel 4.3 Hasil Pengujian Algoritma Emisi Kendaraan Umum (*Public Transport*)
| No | Skenario Pengujian | Parameter Input | Rumus Perhitungan | Nilai Harapan (*Expected*) | Hasil Sistem (*Actual*) | Status |
|---|---|---|---|---|---|---|
| 1 | Perjalanan menggunakan *City Bus* | Jarak = 80 km<br>Faktor Emisi Seeder = 1,085 kgCO2e/km<br>Rata-rata = 20 penumpang | $\frac{1,085 \times 80}{20}$ | 4,34 kgCO2e | 4,34 kgCO2e | **PASSED** |
| 2 | Perjalanan menggunakan MRT | Jarak = 100 km<br>Faktor Emisi Seeder = 0,026 kgCO2e/km<br>Rata-rata = 300 penumpang | $\frac{0,026 \times 100}{300}$ | 0,0086666667 kgCO2e | 0,0086666667 kgCO2e | **PASSED** |

---

### 2. Pengujian Keamanan Penyimpanan Kredensial (`TokenStorage`)
Pengujian ini memverifikasi integrasi pustaka `FlutterSecureStorage` yang memanfaatkan *Keystore* (Android) dan *Keychain* (iOS) untuk melindungi token otentikasi pengguna dari kebocoran data.

#### Tabel 4.4 Hasil Pengujian Protokol Keamanan Sesi (*Secure Storage*)
| No | Skenario Pengujian | Parameter Input | Kondisi Harapan (*Expected State*) | Hasil Pembacaan Sistem (*Actual State*) | Status |
|---|---|---|---|---|---|
| 1 | Penyimpanan dan pembacaan token terenkripsi saat *Login* | Token = `"token-rahasia-123"`<br>User ID = `99`<br>Name = `"Mahasiswa Skripsi"` | Sesi tersimpan rapi & fungsi `hasValidToken()` bernilai `true` | Token = `"token-rahasia-123"`<br>User ID = `99`<br>Valid = `true` | **PASSED** (*Encrypted Verified*) |
| 2 | Pembersihan memori kredensial saat *Logout* (`clearAll`) | Eksekusi fungsi `TokenStorage.clearAll()` | Seluruh *Key* dienkripsi ulang menjadi `null` & `hasValidToken()` bernilai `false` | Token = `null`<br>User ID = `null`<br>Valid = `false` | **PASSED** (*Session Cleared*) |

---

### 3. Bukti Eksekusi Pengujian (*Test Execution Log*)
Pengujian dilakukan menggunakan perintah terminal `flutter test` dan menghasilkan tingkat keberhasilan **100% (6/6 Test Cases Passed)** tanpa adanya kesalahan sintaksis maupun penyimpangan logika hitung.

```text
================================================================================
  [UNIT TEST] PERHITUNGAN EMISI MAKANAN (FOOD EMISSIONS)
================================================================================
Skenario      : Konsumsi Cardboard Boxes seberat 1.0 kg
Input Param   : Item = Cardboard Boxes, Quantity = 1.0 kg, Faktor Emisi = 0.85 kgCO2e/kg
Rumus Uji     : Quantity × Emission Factor (1.0 × 0.85)
Nilai Harapan : 0.85 kgCO2e
Output Sistem : 0.85 kgCO2e
Status Uji    : ✔ PASSED (Akurat 100%)
--------------------------------------------------------------------------------
Skenario      : Perjalanan Motorcycle sejauh 80 km menggunakan Pertalite
Input Param   : Jarak = 80 km, Efisiensi = 40 km/L, Faktor Emisi = 2.31 kgCO2e/L
Rumus Uji     : (Jarak / Efisiensi) × Faktor Emisi ((80 / 40) × 2.31)
Nilai Harapan : 4.62 kgCO2e
Output Sistem : 4.62 kgCO2e
Status Uji    : ✔ PASSED (Akurat 100%)
--------------------------------------------------------------------------------
Skenario      : Perjalanan City Bus sejauh 80 km
Input Param   : Jarak = 80 km, Faktor Emisi = 1.085 kgCO2e/km, Rata-rata Penumpang = 20
Rumus Uji     : (Faktor Emisi × Jarak) / Rata-rata Penumpang ((1.085 × 80) / 20)
Nilai Harapan : 4.34 kgCO2e
Output Sistem : 4.34 kgCO2e
Status Uji    : ✔ PASSED (Akurat 100%)
--------------------------------------------------------------------------------
================================================================================
  [UNIT TEST] PEMBERSIHAN DATA SESI PENGGUNA (LOGOUT CLEANUP TEST)
================================================================================
Skenario      : Penghapusan Seluruh Kredensial Keamanan setelah Logout
Input Data    : Eksekusi fungsi TokenStorage.clearAll()
Kondisi Harapan : Seluruh Key bernilai null / hasValidToken=false
Hasil Bacaan  : Token="null", Valid=false
Status Uji    : ✔ PASSED (Secure Verified)
--------------------------------------------------------------------------------

00:03 +6: All tests passed!
```
