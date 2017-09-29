from ansible.playbook import Playbook
import ansible.parsing.dataloader
import ansible.inventory
from retrying import retry
import argparse
import re
import subprocess
import logging

log = logging.getLogger(__name__)

def config_logging(level=logging.INFO):
	logging.basicConfig(
		level=level,
		format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

def search_role(role=None):
	roles_list = subprocess.check_output(['ansible-galaxy','list'])
	return True if role in roles_list else False

def install_role(role=None):
	install_out = subprocess.check_output(['ansible-galaxy','install',role])
	if "was installed successfully" in install_out:
		return True
	else:
		return False

@retry(stop_max_attempt_number=5)
def load_playbook(playbook=None):
	try:
		pb = Playbook.load(playbook,loader=ansible.parsing.dataloader.DataLoader())
	except ansible.errors.AnsibleError, e:
		p = re.compile("the role '(.*)' was not found")
		m = p.search(str(e))
		if m:
			name = m.group(1)
			if not search_role(name):
				log.info("Installing role: {}".format(name))
				if install_role(name):
					log.info("Successfully installed {}".format(name))
				else:
					log.error("Failed to install {}".format(name))
	except: # done, move on
		pass


def main():
	config_logging(logging.INFO)
	log.info('Started')
	parser = argparse.ArgumentParser()
	parser.add_argument('-f', '--file', help="specify playbook filename")
	args = parser.parse_args()
	log.info("Processing file {0}".format(args.file))
	load_playbook(args.file)
	log.info('Ended')
if __name__ == "__main__":
	main()

