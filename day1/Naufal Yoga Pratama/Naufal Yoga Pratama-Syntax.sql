SELECT
    o.pesanan_id                                          AS "No. Order",
    o.tanggal                                           AS "Tanggal",
    pj.nama_penjual                                     AS "Penjual",
    pb.nama_pembeli                                     AS "Pembeli",
    CONCAT(a.alamat_jalan, ', ', a.alamat_kota, ', ',
           a.alamat_provinsi, ' ', a.alamat_kodepos)    AS "Alamat Tujuan",
    py.metode_pembayaran                                AS "Metode Bayar",
    k.nama_kurir                                        AS "Kurir",
    pr.produk_nama                                      AS "Produk",
    pr.harga_produk                                     AS "Harga Satuan",
    pr.berat_produk                                     AS "Berat (g)",
    od.jumlah_produk                                    AS "Qty",
    (od.jumlah_produk * pr.harga_produk)                AS "Subtotal Harga",
    (od.jumlah_produk * pr.berat_produk)                AS "Subtotal Berat (g)",
    o.biaya_jasa                                        AS "Biaya Jasa"
FROM pesanan o
JOIN penjual      pj  ON o.kode_penjual    = pj.kode_penjual
JOIN pembeli      pb  ON o.kode_pembeli    = pb.kode_pembeli
JOIN alamat       a   ON o.kode_alamat     = a.kode_alamat
JOIN pembayaran   py  ON o.kode_pembayaran = py.kode_pembayaran
JOIN kurir        k   ON o.kode_kurir      = k.kode_kurir
JOIN order_detail od  ON o.pesanan_id        = od.pesanan_id
JOIN produk       pr  ON od.kode_produk    = pr.kode_produk
ORDER BY o.pesanan_id, pr.produk_nama;