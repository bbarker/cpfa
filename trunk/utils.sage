#!/Applications/sage/sage 

import sys
import subprocess
from sage.all import *
#from rpy import * 
import pprint


# A binary ordered tree example

class CNode:
    parent, left, right, data = None, None, None, 0 
    
    def __init__(self, data, parent):
        # initializes the data members
	self.parent = parent 
        self.left = None
        self.right = None
        self.data = data

class CBTree:
    def __init__(self):
        # initializes the root member
        self.root = None
        self.leaf = {}

    def addLeaf(parent, data, newnode):
        del self.leaf[parent]
        self.leaf[data] = newnode
         
 
    def addNode(self, data, parent):
        # creates a new node and returns it
        return CNode(data, parent)
#change the insertion method to insert by parent name, left node first
    def insert(self, root, data, parent):
        # inserts a new data
        if root == None:
            # it there isn't any data
            # adds it and returns
            return self.addNode(data, None)
        else:
            # enters into the tree
	    if parent.startswith(root.data):
                loc = data.partition(rood.data)[2][0]
                if loc == 'l' or loc == 'd' or loc == 'p':
                    self.addLeaf(parent, data, root.left)
                    root.left = self.insert(root.left, data)
                elif loc == 'r' or loc == 'v' or loc == 'a':
                    # processes the right-sub-tree
                    self.addLeaf(parent, data, root.right)
                    root.right = self.insert(root.right, data)
                else:
                    print "Error: Unhandled node: " + data + "\n"
	    elif root.left == None:
                self.addLeaf(parent, data, root.left)
                root.left = self.insert(root.left, data)
            else:
                self.addLeaf(parent, data, root.right)
                root.right = self.insert(root.right, data)
            return root
#currently invalid, could modify lookup to do binary search based on systematic name and then do complete traversal
#when the name of the cell is non-systematic.        
    def lookup(self, root, target):
        # looks for a value into the tree
        if root == None:
            return 0
        else:
            # if it has found it...
            if target == root.data:
                return 1
            else:
                if target < root.data:
                    # left side
                    return self.lookup(root.left, target)
                else:
                    # right side
                    return self.lookup(root.right, target)
        
    def minValue(self, root):
        # goes down into the left
        # arm and returns the last value
        while(root.left != None):
            root = root.left
        return root.data

    def maxDepth(self, root):
        if root == None:
            return 0
        else:
            # computes the two depths
            ldepth = self.maxDepth(root.left)
            rdepth = self.maxDepth(root.right)
            # returns the appropriate depth
            return max(ldepth, rdepth) + 1
            
    def size(self, root):
        if root == None:
            return 0
        else:
            return self.size(root.left) + 1 + self.size(root.right)

    def printTree(self, root):
        # prints the tree path
        if root == None:
            pass
        else:
            self.printTree(root.left)
            print root.data,
            self.printTree(root.right)

    def printRevTree(self, root):
        # prints the tree path in reverse
        # order
        if root == None:
            pass
        else:
            self.printRevTree(root.right)
            print root.data,
            self.printRevTree(root.left)

if __name__ == "__main__":
    # create the binary tree
    BTree = CBTree()
    # add the root node
    root = BTree.addNode(0)
    # ask the user to insert values
    for i in range(0, 5):
        data = int(raw_input("insert the node value nr %d: " % i))
        # insert values
        BTree.insert(root, data)
    print
    
    BTree.printTree(root)
    print
    BTree.printRevTree(root)
    print
    data = int(raw_input("insert a value to find: "))
    if BTree.lookup(root, data):
        print "found"
    else:
        print "not found"
        
    print BTree.minValue(root)
    print BTree.maxDepth(root)
    print BTree.size(root)


