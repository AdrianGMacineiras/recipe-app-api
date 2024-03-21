#Mock el comportamiento de la base de datos
from unittest.mock import patch

#Uno de los posibles errores que puede que tengamos de llamar a la bd antes de que este levantada
from psycopg2 import OperationalError as Psycopg2Error

#Llamar un comando por su nombre 
from django.core.management import call_command
from django.db.utils import OperationalError
#La clase base de test que vamos a usar
from django.test import SimpleTestCase

#Mock
@patch('core.management.commands.wait_for_db.Command.check')
class CommandTest(SimpleTestCase):

    def test_wait_for_db_ready(self, patched_check):
        # Cuando se llame check en nuestro test, queremos que devuelva True
        patched_check.return_value = True
        
        # Ejecuta el codigo de wait_for_db.py
        call_command('wait_for_db')

        # Comprobar si se ha llamado el comando con la base de datos establecida en settings como default
        patched_check.assert_called_once_with(databases=['default'])

    # Simular tiempo de espera, por que queremnos comprobar la base de datos, esperar y volver a comprobar la base de datos
    # Reemplaza la funcion sleep, con un objeto que devuelve un Not a Value, por que no queremos que espere y detenga la ejecución.
    @patch('time.sleep')
    def test_wait_for_db_delay(self, patched_sleep, patched_check):
        # Cuando se quiere mockear un excepción
        # Las primeras 2 veces que llamamos al método, queremos que salte el Psycopg2Error
        # Las siguientes 3 veces, que salte OperationalError
        # Por último que devuelva True
        patched_check.side_effect=[Psycopg2Error] * 2 + [OperationalError] * 3 + [True]

        call_command('wait_for_db')
        
        # Comprobar que se devuelven el numero de excepciones que establecimos previamente
        self.assertEqual(patched_check.call_count, 6)
        patched_check.assert_called_with(databases=['default'])