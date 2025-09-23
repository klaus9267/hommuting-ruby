class KoreaGeohash
  # 서울/경기도 지역의 5글자 geohash 목록
  # 직방 API에서 사용하는 geohash 패턴 기반
  GEOHASH_LIST = [
    # 서울 중심부 (강남권)
    'wydm0', 'wydm1', 'wydm2', 'wydm3', 'wydm4', 'wydm5', 'wydm6', 'wydm7', 'wydm8', 'wydm9',
    'wydmb', 'wydmc', 'wydmd', 'wydme', 'wydmf', 'wydmg', 'wydmh', 'wydmj', 'wydmk', 'wydmm',
    'wydmn', 'wydmp', 'wydmq', 'wydmr', 'wydms', 'wydmt', 'wydmu', 'wydmv', 'wydmw', 'wydmx',
    'wydmy', 'wydmz',

    # 서울 강북권
    'wydq0', 'wydq1', 'wydq2', 'wydq3', 'wydq4', 'wydq5', 'wydq6', 'wydq7', 'wydq8', 'wydq9',
    'wydqb', 'wydqc', 'wydqd', 'wydqe', 'wydqf', 'wydqg', 'wydqh', 'wydqj', 'wydqk', 'wydqm',
    'wydqn', 'wydqp', 'wydqr', 'wydqs', 'wydqt', 'wydqu', 'wydqv', 'wydqw', 'wydqx', 'wydqy',
    'wydqz',

    # 서울 서부권
    'wydj0', 'wydj1', 'wydj2', 'wydj3', 'wydj4', 'wydj5', 'wydj6', 'wydj7', 'wydj8', 'wydj9',
    'wydjb', 'wydjc', 'wydjd', 'wydje', 'wydjf', 'wydjg', 'wydjh', 'wydjj', 'wydjk', 'wydjm',
    'wydjn', 'wydjp', 'wydjr', 'wydjs', 'wydjt', 'wydju', 'wydjv', 'wydjw', 'wydjx', 'wydjy',
    'wydjz',

    # 서울 동부권
    'wydn0', 'wydn1', 'wydn2', 'wydn3', 'wydn4', 'wydn5', 'wydn6', 'wydn7', 'wydn8', 'wydn9',
    'wydnb', 'wydnc', 'wydnd', 'wydne', 'wydnf', 'wydng', 'wydnh', 'wydnj', 'wydnk', 'wydnm',
    'wydnn', 'wydnp', 'wydnr', 'wydns', 'wydnt', 'wydnu', 'wydnv', 'wydnw', 'wydnx', 'wydny',
    'wydnz',

    # 경기도 북부 (고양, 파주, 의정부)
    'wydk0', 'wydk1', 'wydk2', 'wydk3', 'wydk4', 'wydk5', 'wydk6', 'wydk7', 'wydk8', 'wydk9',
    'wydkb', 'wydkc', 'wydkd', 'wydke', 'wydkf', 'wydkg', 'wydkh', 'wydkj', 'wydkk', 'wydkm',
    'wydkn', 'wydkp', 'wydkr', 'wydks', 'wydkt', 'wydku', 'wydkv', 'wydkw', 'wydkx', 'wydky',
    'wydkz',

    # 경기도 서부 (부천, 시흥, 안산, 화성)
    'wydh0', 'wydh1', 'wydh2', 'wydh3', 'wydh4', 'wydh5', 'wydh6', 'wydh7', 'wydh8', 'wydh9',
    'wydhb', 'wydhc', 'wydhd', 'wydhe', 'wydhf', 'wydhg', 'wydhh', 'wydhj', 'wydhk', 'wydhm',
    'wydhn', 'wydhp', 'wydhr', 'wydhs', 'wydht', 'wydhu', 'wydhv', 'wydhw', 'wydhx', 'wydhy',
    'wydhz',

    # 경기도 남부 (수원, 안양, 성남, 용인)
    'wydf0', 'wydf1', 'wydf2', 'wydf3', 'wydf4', 'wydf5', 'wydf6', 'wydf7', 'wydf8', 'wydf9',
    'wydfb', 'wydfc', 'wydfd', 'wydfe', 'wydff', 'wydfg', 'wydfh', 'wydfj', 'wydfk', 'wydfm',
    'wydfn', 'wydfp', 'wydfr', 'wydfs', 'wydft', 'wydfu', 'wydfv', 'wydfw', 'wydfx', 'wydfy',
    'wydfz',

    # 경기도 동부 (하남, 남양주, 구리)
    'wydr0', 'wydr1', 'wydr2', 'wydr3', 'wydr4', 'wydr5', 'wydr6', 'wydr7', 'wydr8', 'wydr9',
    'wydrb', 'wydrc', 'wydrd', 'wydre', 'wydrf', 'wydrg', 'wydrh', 'wydrj', 'wydrk', 'wydrm',
    'wydrn', 'wydrp', 'wydrr', 'wydrs', 'wydrt', 'wydru', 'wydrv', 'wydrw', 'wydrx', 'wydry',
    'wydrz'
  ].freeze

  # 모든 geohash 반환
  def self.all_geohashes
    GEOHASH_LIST
  end

  # 서울 지역 geohash만 반환
  def self.seoul_geohashes
    GEOHASH_LIST.select { |hash| hash.start_with?('wydm', 'wydq', 'wydj', 'wydn') }
  end

  # 경기도 지역 geohash만 반환
  def self.gyeonggi_geohashes
    GEOHASH_LIST.select { |hash| hash.start_with?('wydk', 'wydh', 'wydf', 'wydr') }
  end

  # 특정 지역의 geohash 반환
  def self.geohashes_for_region(region)
    case region.to_sym
    when :seoul
      seoul_geohashes
    when :gyeonggi
      gyeonggi_geohashes
    when :all
      all_geohashes
    else
      []
    end
  end
end