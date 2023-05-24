const yaml                = require('js-yaml');
const fs                  = require('fs');
const { ArgumentParser }  = require('argparse');

const parser = new ArgumentParser({
  description: 'Argparse example'
});

parser.add_argument('--module', {  });

const args = parser.parse_args();


// Get document, or throw exception on error
try {
  const doc = yaml.load(fs.readFileSync(args.module, 'utf8'));
  const damageTypes = ["chop", "slash", "thrust"];
  for (const key in doc.records) {
    const record = doc.records[key];
    if (record.type === "Weapon") {
      const map = {};
      for (const damageType of damageTypes) {
        map[(record[damageType][0] + record[damageType][1]) / 2] = damageType;
      }
      const bestDamageType = map[Math.max(...Object.keys(map).map(Number))];
      for (const damageType of damageTypes) {
        record[damageType] = record[bestDamageType];
      }
      record.reach = record.reach / 2;
    }
  }
} catch (e) {
  console.log(e);
}