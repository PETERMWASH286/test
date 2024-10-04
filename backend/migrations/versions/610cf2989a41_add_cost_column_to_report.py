"""Add cost column to report

Revision ID: 610cf2989a41
Revises: 1b02e4308233
Create Date: 2024-10-04 08:44:01.931420

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '610cf2989a41'
down_revision = '1b02e4308233'
branch_labels = None
depends_on = None


def upgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('report', schema=None) as batch_op:
        batch_op.add_column(sa.Column('cost', sa.Float(), nullable=True))

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('report', schema=None) as batch_op:
        batch_op.drop_column('cost')

    # ### end Alembic commands ###
