# AuthService

💧 A project built with the Vapor web framework, organized using **Clean Architecture**.

## Struktur Proyek
```
/dev/null/structure.txt#L1-16
Sources/AuthService/
├─ App/
│  ├─ entrypoint.swift
│  └─ configure.swift
├─ Presentation/
│  ├─ Controllers/
│  └─ Routes/
├─ Application/
│  └─ DTOs/
├─ Domain/
│  └─ Entities/
└─ Infrastructure/
   └─ Migrations/
```

## Tanggung Jawab Layer
- `App`: composition root. Mengatur konfigurasi aplikasi, registrasi `routes`, dan `migrations`.
- `Presentation`: layer HTTP (controller, route). Fokus pada request/response.
- `Application`: use case & DTO. Tempat orkestrasi logika aplikasi.
- `Domain`: entitas & aturan bisnis inti.
- `Infrastructure`: detail teknis (database, migrations, cache, third-party services).

## Menjalankan Proyek
Build:
```
/dev/null/commands.txt#L1-1
swift build
```

Run:
```
/dev/null/commands.txt#L1-1
swift run
```

Test:
```
/dev/null/commands.txt#L1-1
swift test
```

## Konfigurasi Database
Konfigurasi database berada di `Sources/AuthService/App/configure.swift` dan menggunakan environment variables:
- `DATABASE_HOST`
- `DATABASE_PORT`
- `DATABASE_USERNAME`
- `DATABASE_PASSWORD`
- `DATABASE_NAME`

Jika memakai `docker-compose.yml`, variabel ini sudah disediakan.

## Panduan Menambah Fitur (Ringkas)
1. Tambah entity baru di `Domain/Entities`.
2. Tambah DTO di `Application/DTOs`.
3. Tambah controller & route di `Presentation`.
4. Tambah migration di `Infrastructure/Migrations`.
5. Daftarkan route di `Presentation/Routes/routes.swift` dan migration di `App/configure.swift`.

## Referensi
- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
