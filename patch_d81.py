
#!/usr/bin/env python3

from pathlib import Path
import sys

SECTOR_SIZE = 256
SECTORS_PER_TRACK = 40
D81_SIZE = 819200

# Key = payload filename on disk
# Value = file-relative offset of its 3-byte patch record in the IFFL header.
# Record layout: track, sector, byte offset.
PATCHES = {
    "GAME.PRG": 0x20,
    "DATA.SEQ": 0x23,
}


def sector_offset(track, sector):
    if not (1 <= track <= 80 and 0 <= sector <= 39):
        raise ValueError(f"Invalid D81 address {track}/{sector}")

    return ((track - 1) * SECTORS_PER_TRACK + sector) * SECTOR_SIZE


def read_sector(image, track, sector):
    pos = sector_offset(track, sector)
    return bytes(image[pos:pos + SECTOR_SIZE])


def write_sector(image, track, sector, block):
    pos = sector_offset(track, sector)
    image[pos:pos + SECTOR_SIZE] = block


def decode_filename(raw):
    # Standard CBM filenames are padded with $A0.
    return raw.split(b"\xA0", 1)[0].decode(
        "ascii", errors="replace"
    ).strip().upper()


def find_file(image, filename):
    """Return the starting track and sector of a directory file."""
    track, sector = 40, 3
    visited = set()
    wanted = filename.upper()

    while track:
        if (track, sector) in visited:
            raise ValueError("Directory chain loop")

        visited.add((track, sector))
        block = read_sector(image, track, sector)
        next_track, next_sector = block[0], block[1]

        for i in range(8):
            pos = 2 + i * 32
            entry = block[pos:pos + 30]

            file_type = entry[0]

            if (file_type & 0x0F) == 0:
                continue

            name = decode_filename(entry[3:19])

            if name == wanted:
                start_track, start_sector = entry[1], entry[2]

                if start_track == 0:
                    raise ValueError(
                        f"{filename} has no allocated data sectors"
                    )

                return start_track, start_sector

        track, sector = next_track, next_sector

        if track and not (
            1 <= track <= 80 and 0 <= sector <= 39
        ):
            raise ValueError("Invalid directory pointer")

    raise FileNotFoundError(filename)


def get_chain(image, start_track, start_sector):
    """Return (track, sector, valid_data_length) for each file block."""
    chain = []
    visited = set()
    track, sector = start_track, start_sector

    while track:
        if (track, sector) in visited:
            raise ValueError(
                f"File chain loop at {track}/{sector}"
            )

        visited.add((track, sector))
        block = read_sector(image, track, sector)
        next_track, next_sector = block[0], block[1]

        if next_track == 0:
            # Final block: byte 1 stores the end boundary.
            valid_length = max(0, min(254, next_sector - 1))
            chain.append((track, sector, valid_length))
            break

        if not (
            1 <= next_track <= 80 and 0 <= next_sector <= 39
        ):
            raise ValueError("Invalid file-sector pointer")

        chain.append((track, sector, 254))
        track, sector = next_track, next_sector

    return chain


def locate_byte(chain, file_offset):
    """Map a file-data offset to (track, sector, byte offset)."""
    if file_offset < 0:
        raise ValueError("Negative file offset")

    remaining = file_offset

    for track, sector, length in chain:
        if remaining < length:
            return track, sector, remaining + 2

        remaining -= length

    raise ValueError(
        f"File offset {file_offset} is outside the file"
    )


def read_file(image, chain, offset, length):
    result = bytearray()

    for i in range(length):
        track, sector, pos = locate_byte(chain, offset + i)
        result.append(read_sector(image, track, sector)[pos])

    return bytes(result)


def write_file(image, chain, offset, data):
    for i, value in enumerate(data):
        track, sector, pos = locate_byte(chain, offset + i)
        block = bytearray(read_sector(image, track, sector))
        block[pos] = value
        write_sector(image, track, sector, block)


def main(disk_filename, iffl_filename):
    path = Path(disk_filename)
    image = bytearray(path.read_bytes())

    if len(image) != D81_SIZE:
        raise ValueError(
            f"Expected {D81_SIZE} bytes, got {len(image)}"
        )

    # Check the standard 1581 DOS identifier.
    header = read_sector(image, 40, 0)

    # commented out because I'm using a 5-char identifier. naughty but nice.
    #if header[26:28] != b"3D":
    #    raise ValueError("Not a standard 1581 D81 image")

    if header[0] != 40 or header[1] != 3:
        raise ValueError("Unexpected D81 directory pointer")

    # Find the IFFL file using the command-line filename.
    it, isec = find_file(image, iffl_filename)
    iffl_chain = get_chain(image, it, isec)

    print(
        f"IFFL file '{iffl_filename}' starts at {it}/{isec}"
    )

    # Locate each payload file and patch its location record.
    for filename, table_offset in PATCHES.items():
        track, sector = find_file(image, filename)
        chain = get_chain(image, track, sector)

        # Record: starting track, starting sector, data offset.
        record = bytes((track, sector, 2))

        write_file(image, iffl_chain, table_offset, record)

        print(
            f"{filename}: track={track}, sector={sector}, "
            f"offset=$02; IFFL table offset=${table_offset:04X}"
        )

    # Verify all records after patching.
    for filename, table_offset in PATCHES.items():
        record = read_file(image, iffl_chain, table_offset, 3)
        expected_track, expected_sector = find_file(image, filename)

        expected = bytes((expected_track, expected_sector, 2))

        if record != expected:
            raise ValueError(
                f"Verification failed for {filename}: "
                f"got {record.hex()}, expected {expected.hex()}"
            )

        print(f"Verified {filename}")

    # Write a separate output image, preserving the original.
    output = path.with_name(
        path.stem + "_patched" + path.suffix
    )

    output.write_bytes(image)
    print(f"Written: {output}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            f"Usage: {sys.argv[0]} disk.d81 IFFL_FILENAME"
        )
        sys.exit(2)

    main(sys.argv[1], sys.argv[2])