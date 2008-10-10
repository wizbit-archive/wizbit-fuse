import fuse
import wizbit

class WizbitFs(fuse.Fuse):

    def __init__(self):
        self.store = wizbit.Store()

    def read(self, path):
        bit = wizbit.Bit(self.store, path):
        version = wizbit.Version(bit, bit.primary_tip)

    def write(self, path):
        pass

if __name__ == "__main__":
    server = WizbitFs()
    server.threaded = False
    server.main()
