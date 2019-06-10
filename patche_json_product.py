import json

def merge_two_dicts(x, y):
    z = x.copy()   # start with x's keys and values
    z.update(y)    # modifies z with y's keys and values & returns None
    return z

with open('extensions.json') as json_file:  
    extensions = json.load(json_file)

with open('./VSCode-linux-arm64/resources/app/product.json') as json_file2:
    product = json.load(json_file2)

z = merge_two_dicts(product, extensions)

with open('product_out.json', 'w') as outfile:
    json.dump(z, outfile, indent=4)

