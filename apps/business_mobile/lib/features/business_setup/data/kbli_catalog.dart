class KbliOption {
  final String code;
  final String name;
  final String description;

  const KbliOption({
    required this.code,
    required this.name,
    required this.description,
  });
}

class KbliCatalog {
  static const List<KbliOption> options = [
    KbliOption(
      code: '47111',
      name: 'Perdagangan Eceran Berbagai Macam Barang',
      description: 'Perdagangan eceran berbagai macam barang di toko.',
    ),
    KbliOption(
      code: '47112',
      name: 'Perdagangan Eceran Makanan',
      description: 'Perdagangan eceran makanan dan kebutuhan sehari-hari.',
    ),
    KbliOption(
      code: '47911',
      name: 'Perdagangan Eceran Melalui Internet',
      description: 'Perdagangan eceran melalui internet atau online seller.',
    ),
    KbliOption(
      code: '56101',
      name: 'Restoran',
      description: 'Kegiatan penyediaan makanan dan minuman untuk dikonsumsi.',
    ),
    KbliOption(
      code: '56303',
      name: 'Rumah Minum/Kafe',
      description: 'Penyediaan minuman untuk dikonsumsi di tempat.',
    ),
    KbliOption(
      code: '62010',
      name: 'Aktivitas Pemrograman Komputer',
      description: 'Kegiatan pemrograman dan pengembangan perangkat lunak.',
    ),
    KbliOption(
      code: '85500',
      name: 'Jasa Pendidikan',
      description: 'Kegiatan pendidikan dan pelatihan.',
    ),
    KbliOption(
      code: '79111',
      name: 'Aktivitas Agen Perjalanan Wisata',
      description: 'Kegiatan agen perjalanan dan jasa terkait perjalanan.',
    ),
  ];
}
