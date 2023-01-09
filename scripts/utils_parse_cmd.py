x = "test -a -b cab dcd -e fg"

def parse_cmd(x):
    v = x.split(' ')
    pos = []
    opt = {}
    sw = ''
    for i in v:
        if i.startswith('-'):
            if sw != '':
                opt[sw] = True
            sw = i
        else:
            if sw == '':
                pos.append(i)
            else:
                opt[sw] = i
                sw = ''
    opt['args'] = pos
    return opt

if __name__ == '__main__':
    for i in range(10000):
        print(parse_cmd(x))