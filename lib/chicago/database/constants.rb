module Chicago
  module Database
    # The maximum number an unsigned tinyint column can hold.
    TINY_INT_MAX   = 255

    # The maximum number an unsigned smallint column can hold.
    SMALL_INT_MAX  = 65_535

    # The maximum number an unsigned mediumint column can hold.
    MEDIUM_INT_MAX = 16_777_215

    # The maximum number an unsigned int column can hold.
    INT_MAX        = 4_294_967_295

    # The maximum number an unsigned bigint column can hold.
    BIG_INT_MAX    = 18_446_744_073_709_551_615
  end
end
