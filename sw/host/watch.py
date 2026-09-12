import serial
import struct
import argparse
import sys
from datetime import datetime

# Watchpoint Event Packet Format (9 bytes)
# Timestamp (32-bit): bytes 0-3
# Core ID (8-bit): byte 4
# Value (32-bit): bytes 5-8

def parse_packet(packet_bytes):
    if len(packet_bytes) != 9:
        return None
    
    timestamp, core_id, value = struct.unpack('>IBI', packet_bytes)
    return timestamp, core_id, value

def main():
    parser = argparse.ArgumentParser(description='Live Variable Watch for Multicore Debugging')
    parser.add_argument('--port', type=str, default='COM1', help='Serial port to read from')
    parser.add_argument('--baud', type=int, default=115200, help='Baud rate')
    parser.add_argument('--live', type=str, required=True, help='Variable or Address being watched (e.g., 0x1000)')
    
    args = parser.parse_args()
    
    print(f"[*] Starting live watch on variable {args.live}...")
    print(f"[*] Listening on {args.port} at {args.baud} baud\n")
    
    try:
        ser = serial.Serial(args.port, args.baud, timeout=1)
        
        print("Timeline:")
        print("-" * 60)
        
        # Read from the real serial port
        while True:
            packet = ser.read(9)
            if len(packet) == 9:
                ts, cid, val = parse_packet(packet)
                print(f"[t={ts}ns] core{cid} wrote {args.live} = {val:#010x} ({val})")
                
    except serial.SerialException as e:
        print(f"\nSerial Error: {e}")
        print(f"Could not open {args.port}. Ensure the port is correct and not in use by another program.")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n[*] Stopping live watch.")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
