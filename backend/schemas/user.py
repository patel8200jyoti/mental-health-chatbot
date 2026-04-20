from datetime import datetime,date
from utils.security import hash_password
from typing import Optional
from uuid import uuid4


def user_entity(user)-> dict :
    '''the mongo db way '''
    dob = user.get('user_dob')
    if dob and isinstance(dob, date):
        dob = datetime(dob.year, dob.month, dob.day)
        
    return {
        'user_id' : str(uuid4()),
        'user_email': user['user_email'],
        'user_name' : user['user_name'],
        'password' : hash_password(user['password']),
        'user_dob' : dob,
        'user_gender' : user.get('user_gender'),
        'created_at' : datetime.utcnow(),
        'updated_at': datetime.utcnow(),
        'disabled': False,
        'role': 'user'
    }
    
def user_schema(user):
    return {
        'id':          str(user['_id']),
        'user_id':     str(user.get('user_id', '')),
        'user_email':  user.get('user_email', ''),
        
        # professionals have full_name, users have user_name
        'user_name':   user.get('user_name') or user.get('full_name', ''),
        'full_name':   user.get('full_name') or user.get('user_name', ''),
        
        'role':        user.get('role', 'user'),
        'is_approved': user.get('is_approved', False),
        'disabled':    user.get('disabled', False),
        
        # optional fields — safe defaults
        'user_dob':    user.get('user_dob', ''),
        'user_gender': user.get('user_gender', ''),
        
        # professional-specific
        'medical_registration_number': user.get('medical_registration_number', ''),
        'state_medical_council':       user.get('state_medical_council', ''),
        'year_of_registration':        user.get('year_of_registration', ''),
        'educational_qualifications':  user.get('educational_qualifications', ''),
    }

