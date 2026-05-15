import zmq
import sys
import argparse

def control_ffmpeg():
    parser = argparse.ArgumentParser(description="FFmpeg OSD config through ZMQ")
    
    # which camera
    parser.add_argument("cam_id", type=int, help="Camera number")

    # which OSD item
    parser.add_argument("target", choices=["cam", "time"], help="OSD target")

    # OSD position stuff
    parser.add_argument("-top", action="store_true")
    parser.add_argument("-bottom", action="store_true")
    parser.add_argument("-left", action="store_true")
    parser.add_argument("-right", action="store_true")
    
    # OSD contents
    parser.add_argument("-text", type=str, help="Texte libre")
    parser.add_argument("-time", action="store_true", help="Format: HH:MM:SS")
    parser.add_argument("-timeprec", action="store_true", help="Format: HH:MM:SS.mmm")
    parser.add_argument("-timeshort", action="store_true", help="Format: HH:MM")
    parser.add_argument("-exp", type=str, help="Expression brute")

    args = parser.parse_args()

    # 1. consistency check
    # Positions
    if args.top and args.bottom:
        print("Error : -top and -bottom are mutually exclusive."); sys.exit(1)
    if args.left and args.right:
        print("Error : -left and -right are mutually exclusive."); sys.exit(1)

    # content. either text, time, timeprec, timeshort, exp
    text_options = [args.text, args.time, args.timeprec, args.timeshort, args.exp]
    if sum(1 for opt in text_options if opt) > 1:
        print("Error : The content options (-text, -time, -timeprec, -timeshort, -exp) are mutually exclusive.")
        sys.exit(1)

    # 2. build the parameters string
    final_params = []

    if args.exp:
        final_params.append(args.exp)
    else:
        # Positions
        if args.top: final_params.append("y=30")
        if args.bottom: final_params.append("y=h-th-40")
        if args.left: final_params.append("x=30")
        if args.right: final_params.append("x=w-tw-30")
        
        # Contenu
        if args.text:
            final_params.append(f"text='{args.text}'")
        elif args.time:
            final_params.append("text='%{localtime\\:%H\\\\\\:%M\\\\\\:%S}'")
        elif args.timeshort:
            final_params.append("text='%{localtime\\:%H\\\\\\:%M}'")
        elif args.timeprec:
            final_params.append("text='%{localtime\\:%H\\\\\\:%M\\\\\\:%S.%3N}'")

    if not final_params:
        print("Error: nothing to do."); sys.exit(1)

    # 3. join and send
    expression_string = ":".join(final_params)
    payload = f"drawtext@drawtext_{args.target} reinit {expression_string}"
    
    port = 19000 + args.cam_id
    address = f"tcp://127.0.0.1:{port}"

    try:
        ctx = zmq.Context()
        sock = ctx.socket(zmq.REQ)
        sock.setsockopt(zmq.RCVTIMEO, 2000)
        sock.connect(address)
        
        print(f"Cam {args.cam_id} -> {payload}")
        sock.send_string(payload)
        print(f"Response: {sock.recv_string()}")
    except zmq.error.Again:
        print(f"Error: Timeout on {address}")
    finally:
        sock.close()
        ctx.term()

if __name__ == "__main__":
    control_ffmpeg()
