import 'dart:convert';

const dashboardJson = r'''
{
  "metrics": [
    {"value": "5,991", "unit": "Linen", "title": "Linen & Tirai Ready", "action": "Lihat Data"},
    {"value": "2,320", "unit": "Linen", "title": "Linen & Tirai di Laundry", "action": "Lihat Data"},
    {"value": "2,171", "unit": "Linen", "title": "Linen & Tirai di Ruangan", "action": "Lihat Data"}
  ],
  "categories": [
    {"label": "Linen & Tirai\nRusak", "color": 4294901760},
    {"label": "Linen & Tirai\nHilang", "color": 4294901760}
  ],
  "categoryDetails": [
    {"title": "Linen & Tirai Rusak", "subtitle": "LINEN & TIRAI RUSAK", "columns": ["Nama Linen", "QR Code", "Jam", "Tanggal", "Tahun Pembuatan"], "rows": [["Baju Bayi", "", "00:00", "27/03/2026", "27/03/2026"], ["", "", "00:00", "27/03/2026", "27/03/2026"], ["", "", "00:00", "27/03/2026", "27/03/2026"], ["", "", "00:00", "27/03/2026", "27/03/2026"]]},
    {"title": "Linen & Tirai Hilang", "subtitle": "LINEN & TIRAI HILANG", "columns": ["Ruangan", "Nama Linen", "QR Code", "Tanggal Transaksi Terakhir", "Tanggal Hilang"], "rows": [["", "", "", "27/03/2026", "27/03/2026"], ["", "", "", "27/03/2026", "27/03/2026"], ["", "", "", "27/03/2026", "27/03/2026"], ["", "", "", "27/03/2026", "27/03/2026"]]}
  ],
  "transactions": [
    {"label": "Linen & Tirai\nKeluar", "color": 4294901760},
    {"label": "Linen & Tirai\nMasuk", "color": 4294901760},
    {"label": "Permintaan\nRuangan", "color": 4294901760}
  ],
  "rooms": [
    {"name": "Anak", "in": 0, "out": 0, "difference": 0},
    {"name": "Bank Darah", "in": 0, "out": 0, "difference": 0},
    {"name": "Rawat Jalan", "in": 0, "out": 0, "difference": 0},
    {"name": "Rawat Inap", "in": 0, "out": 0, "difference": 0},
    {"name": "Cathlab", "in": 0, "out": 0, "difference": 0},
    {"name": "R. Cendana", "in": 0, "out": 0, "difference": 0}
  ],
  "linenDetails": [
    {"title": "Linen & Tirai Ready", "subtitle": "LINEN & TIRAI READY", "columns": ["Nama Kategori", "Nama Linen", "Stock Ready", "Action"], "rows": [["Perlengkapan Bayi", "Baju Bayi", 20, "Lihat"], ["Rawat Inap", "Baju Hacino", 50, "Lihat"], ["Rawat Jalan", "Celana Hacino", 200, "Lihat"]]},
    {"title": "Linen & Tirai di Laundry", "subtitle": "LINEN & TIRAI DI LAUNDRY", "columns": ["Nama Linen", "Nama Kategori", "Ready", "Action"], "rows": [["Baju Bayi", "Perlengkapan Oka", 20, "Lihat"], ["Baju Hacino", "Rawat Inap", 50, "Lihat"], ["Celana Hacino", "Rawat Jalan", 200, "Lihat"]]},
    {"title": "Linen & Tirai di Ruangan", "subtitle": "LINEN & TIRAI DI RUANGAN", "columns": ["Nama Ruangan", "Stock Awal", "Hilang", "Linen di Ruangan", "Action"], "rows": [["Anak", 0, 0, 0, "Lihat"], ["Bank Darah", 0, 0, 0, "Lihat"], ["Rawat Jalan", 0, 0, 0, "Lihat"], ["Rawat Inap", 0, 0, 0, "Lihat"]]}
  ]
  ,
  "transactionDetails": [
    {"title": "Linen & Tirai Keluar", "subtitle": "LINEN & TIRAI KELUAR", "columns": ["ke Ruangan", "Jumlah", "Jam", "Tanggal", "Action"], "rows": [["", 0, "00:00", "20/03/2026", "Lihat"], ["", 0, "00:00", "20/03/2026", "Lihat"], ["", 0, "00:00", "20/03/2026", "Lihat"]]},
    {"title": "Linen & Tirai Masuk", "subtitle": "LINEN & TIRAI MASUK", "columns": ["dari Ruangan", "Jumlah", "Jam", "Tanggal", "Action"], "rows": [["", 0, "00:00", "20/03/2026", "Lihat"], ["", 0, "00:00", "20/03/2026", "Lihat"], ["", 0, "00:00", "20/03/2026", "Lihat"]]}
  ]
  ,
  "requests": {
    "list": [
      {"date": "27/03/2026", "room": "Anak", "room_head": "Ibu A", "status": "Pending"},
      {"date": "27/03/2026", "room": "Rawat Inap", "room_head": "Bapak B", "status": "Approved"},
      {"date": "27/03/2026", "room": "Rawat Jalan", "room_head": "Ibu C", "status": "Pending"}
    ],
    "items_template_columns": ["Nama Linen", "Kategori Linen", "Jumlah"]
  }
  ,
  "rfid_items": {
    "E280689400005014B07829D4": {
      "tag": "E280689400005014B07829D4",
      "nama_linen": "Duk Besar 210 x 250",
      "kategori": "Set OK",
      "pemakaian": 3,
      "posisi_terakhir": "IGD",
      "tanggal_masuk": "2026-01-06",
      "tanggal_keluar": "2026-01-06"
    }
  }
}
''';

final Map<String, dynamic> dashboardData = jsonDecode(dashboardJson) as Map<String, dynamic>;