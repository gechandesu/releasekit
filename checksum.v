module releasekit

import crypto.sha1
import crypto.sha256
import crypto.sha512
import hash
import io
import os

pub enum HashFn {
	sha1
	sha256
	sha512
}

// checksum returns a hex checksum of file in path.
// This function output is the same as `cksum --algorithm=TYPE --untagged FILEPATH` command.
pub fn checksum(path string, hashfn HashFn) !string {
	sum := match hashfn {
		.sha1 {
			sha1sum(path)!
		}
		.sha256 {
			sha256sum(path)!
		}
		.sha512 {
			sha512sum(path)!
		}
	}

	return '${sum}  ${path}\n'
}

// sha1sum reads a file from disk using a buffer and calculates its SHA1 checksum,
// output is HEX digest.
pub fn sha1sum(path string) !string {
	mut sum := ''
	mut file := os.open(path)!
	mut digest := sha1.new()
	read_file_and_write_digest(mut digest, mut file, buf_size)!
	sum = digest.sum([]).hex()
	file.close()
	return sum
}

// sha256sum reads a file from disk using a buffer and calculates its 256 bit SHA2 checksum,
// output is HEX digest.
pub fn sha256sum(path string) !string {
	mut sum := ''
	mut file := os.open(path)!
	mut digest := sha256.new()
	read_file_and_write_digest(mut digest, mut file, buf_size)!
	sum = digest.sum([]).hex()
	file.close()
	return sum
}

// sha512sum reads a file from disk using a buffer and calculates its 512 bit SHA2 checksum,
// output is HEX digest.
pub fn sha512sum(path string) !string {
	mut sum := ''
	mut file := os.open(path)!
	mut digest := sha512.new()
	read_file_and_write_digest(mut digest, mut file, buf_size)!
	sum = digest.sum([]).hex()
	file.close()
	return sum
}

const buf_size = 131_072 // 128 KiB

fn read_file_and_write_digest(mut digest hash.Hash, mut file os.File, buf_size int) ! {
	mut buf := []u8{len: buf_size, cap: buf_size}
	for {
		n := file.read(mut buf) or {
			if err is io.Eof || err is os.Eof {
				break
			} else {
				return error_with_code('file read error', err.code())
			}
		}
		if n == 0 {
			break
		}
		digest.write(buf[..n]) or {}
	}
}
