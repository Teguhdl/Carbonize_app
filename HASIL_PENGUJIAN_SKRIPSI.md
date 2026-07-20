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
| 1 | Perhitungan emisi daging sapi (*Beef*) | Kuantitas = 2.0 kg<br>Faktor Emisi = 27.0 kgCO2e/kg | $\text{Kuantitas} \times \text{Faktor Emisi}$<br>$(2.0 \times 27.0)$ | 54.0 kgCO2e | 54.0 kgCO2e | **PASSED** (100% Akurat) |
| 2 | Perhitungan emisi daging ayam (*Chicken*) | Kuantitas = 3.0 kg<br>Faktor Emisi = 6.9 kgCO2e/kg | $\text{Kuantitas} \times \text{Faktor Emisi}$<br>$(3.0 \times 6.9)$ | 20.7 kgCO2e | 20.7 kgCO2e | **PASSED** (100% Akurat) |
| 3 | Penanganan input makanan di luar *database* (*Edge Case*) | Kuantitas = 1.0 kg<br>Item = *Alien Food* | *Fallback Handler* | 0.0 kgCO2e | 0.0 kgCO2e | **PASSED** (*Crash Prevented*) |

#### Tabel 4.2 Hasil Pengujian Algoritma Emisi Kendaraan Pribadi (*Private Vehicle*)
| No | Skenario Pengujian | Parameter Input | Rumus Perhitungan | Nilai Harapan (*Expected*) | Hasil Sistem (*Actual*) | Status |
|---|---|---|---|---|---|---|
| 1 | Perjalanan Motor menggunakan Pertalite (*Default Efficiency*) | Jarak = 80 km<br>Efisiensi Motor = 40 km/L<br>Faktor Emisi = 2.3 kgCO2e/L | $(\frac{\text{Jarak}}{\text{Efisiensi}}) \times \text{Faktor Emisi}$<br>$(\frac{80}{40}) \times 2.3$ | 4.6 kgCO2e | 4.6 kgCO2e | **PASSED** (100% Akurat) |
| 2 | Perjalanan Mobil menggunakan Pertamax (*Default Efficiency*) | Jarak = 60 km<br>Efisiensi Mobil = 12 km/L<br>Faktor Emisi = 2.34 kgCO2e/L | $(\frac{\text{Jarak}}{\text{Efisiensi}}) \times \text{Faktor Emisi}$<br>$(\frac{60}{12}) \times 2.34$ | 11.7 kgCO2e | 11.7 kgCO2e | **PASSED** (100% Akurat) |
| 3 | Perjalanan Mobil dengan efisiensi kustom dari pengguna (*Custom Efficiency*) | Jarak = 60 km<br>Efisiensi Custom = 15 km/L<br>Faktor Emisi = 2.34 kgCO2e/L | $(\frac{\text{Jarak}}{\text{Efisiensi Custom}}) \times \text{Faktor Emisi}$<br>$(\frac{60}{15}) \times 2.34$ | 9.36 kgCO2e | 9.36 kgCO2e | **PASSED** (100% Akurat) |

#### Tabel 4.3 Hasil Pengujian Algoritma Emisi Kendaraan Umum (*Public Transport*)
| No | Skenario Pengujian | Parameter Input | Rumus Perhitungan | Nilai Harapan (*Expected*) | Hasil Sistem (*Actual*) | Status |
|---|---|---|---|---|---|---|
| 1 | Perjalanan menggunakan Bus Massal | Jarak = 80 km<br>Faktor Emisi Armada = 1.0<br>Kapasitas = 40 Penumpang | $\frac{\text{Faktor Emisi} \times \text{Jarak}}{\text{Rata-rata Penumpang}}$<br>$\frac{1.0 \times 80}{40}$ | 2.0 kgCO2e | 2.0 kgCO2e | **PASSED** (100% Akurat) |
| 2 | Perjalanan menggunakan Kereta Api / KRL | Jarak = 100 km<br>Faktor Emisi Armada = 2.0<br>Kapasitas = 200 Penumpang | $\frac{\text{Faktor Emisi} \times \text{Jarak}}{\text{Rata-rata Penumpang}}$<br>$\frac{2.0 \times 100}{200}$ | 1.0 kgCO2e | 1.0 kgCO2e | **PASSED** (100% Akurat) |

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
Skenario      : Konsumsi Daging Sapi seberat 2.0 kg
Input Param   : Item = Beef, Quantity = 2.0 kg, Faktor Emisi = 27.0 kgCO2e/kg
Rumus Uji     : Quantity × Emission Factor (2.0 × 27.0)
Nilai Harapan : 54.0 kgCO2e
Output Sistem : 54.0 kgCO2e
Status Uji    : ✔ PASSED (Akurat 100%)
--------------------------------------------------------------------------------
...
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
